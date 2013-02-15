      SUBROUTINE OptGraph(IOP,Iout,IDA,IS,IC3,MDist,maxl,scalePPG,Dist)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
C  This subroutine optimizes the fullerene graph using spring embedding
      DIMENSION Dist(2,NMAX),IC3(NMAX,3)
      DIMENSION IDA(NMAX,NMAX),IS(6),MDist(NMAX,NMAX)
      Data Rdist,ftol,conv/1.d0,.5d-10,1 6.0221367d-3/
      rmin=1.d10
      rmax=0.d0
      rper=0.d0
      maxd=0
      do i=1,number_vertices
      do j=i+1,number_vertices
       if(IDA(I,J).eq.1) then
        x=Dist(1,I)-Dist(1,J)
        y=Dist(2,I)-Dist(2,J)
        rd=dsqrt(x*x+y*y)
        if(rd.lt.rmin) rmin=rd
        if(rd.gt.rmax) rmax=rd
       endif
      enddo
        rv=dsqrt(Dist(1,I)**2+Dist(2,I)**2)
        if(rv.gt.rper) rper=rv
      enddo
      scale=Rdist/rmin
      If(IOP.eq.1) Write(IOUT,101)
      If(IOP.eq.2) Write(IOUT,102)
      If(IOP.eq.3) then
       do i=1,number_vertices
       do j=i+1,number_vertices
        if(Mdist(i,j).gt.maxd) maxd=Mdist(i,j)
       enddo
       enddo
       rper=rper*scale
       Write(IOUT,103) maxd,rper,scalePPG
       RAA=scalePPG
      endif
      if(IOP.eq.4) then
       RAA=rmax*scale/dfloat(maxl)
       Write(IOUT,104) maxl,RAA
      endif
      Write(IOUT,1000) rmin,Rdist
      do i=1,number_vertices
       Dist(1,i)=Dist(1,i)*scale 
       Dist(2,i)=Dist(2,i)*scale 
       WRITE(IOUT,1001) I,Dist(1,I),Dist(2,I),(IC3(I,J),J=1,3)
      enddo
      CALL frprmn2d(IOP,IDA,Iout,IS,MDist,
     1 maxd,Dist,ftol,iter,fret,E0,RAA)
      if(fret-E0.gt.1.d-2) then
       fretn=(fret-E0)/dfloat(number_vertices)
       Write(IOUT,1002) fretn
      endif

  101 Format(/1X,'Optimization of fullerene graph using a ',
     1 'simple spring embedding algorithm for edges',
     1 /1X,'Energy at starting point set to zero')
  102 Format(/1X,'Optimization of fullerene graph using a ',
     1 'spring embedding algorithm for edges plus ',
     1 'Coulomb repulsion between barycenter and vertices',
     1 /1X,'Energy at starting point set to zero')
  103 Format(/1X,'Optimization of fullerene graph using a ',
     1 'scaled spring embedding algorithm for edges ',
     1 '(Pisanski-Plestenjak-Graovac algorithm)',
     1 /1X,'Max graph distance to periphery: ',I5,
     1 /1X,'Distance from barycenter to periphery: ',F15.4,
     1 /1X,'Scaling factor for exponential: ',F15.4,
     1 /1X,'Energy at starting point set to zero')
  104 Format(/1X,'Optimization of fullerene graph using a ',
     1 'Kamada-Kawai embedding algorithm',/1X,
     1 'Max integer graph distance: ',I5,', length of ',
     1 'display square area: ',F15.4,
     1 /1X,'Energy at starting point set to zero')
 1000 Format(/1X,'Fletcher-Reeves-Polak-Ribiere optimization',
     1 /1X,'Smallest distance in Tutte graph: ',F12.6,
     1 /1X,'Smallest distance reset to ',F12.6,
     1 /1X,'Rescaled Tutte graph coordinates:',
     1 /1X,'  Atom       X            Y        N1   N2   N3')
 1001 Format(1X,I4,2(1X,F12.6),1X,3(1X,I4))
 1002 Format(1X,'Energy gain per vertex: ',F12.6)

      Return 
      END

      SUBROUTINE frprmn2d(IOP,AH,Iout,IS,MDist,
     1 maxd,p,ftol,iter,fret,E0,RAA)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (ITMAX=500,EPS=1.d-10)
      Real*8 p(NMAX*2),g(NMAX*2),h(NMAX*2),xi(NMAX*2)
      Real*8 pcom(NMAX*2),xicom(NMAX*2)
      Integer AH(NMAX,NMAX),IS(6),MDist(NMAX,NMAX)
C     Given a starting point p that is a vector of length n, Fletcher-Reeves-Polak-Ribiere minimization
C     is performed on a function func3d, using its gradient as calculated by a routine dfunc3d.
C     The convergence tolerance on the function value is input as ftol. Returned quantities are
C     p (the location of the minimum), iter (the number of iterations that were performed),
C     and fret (the minimum value of the function). The routine linmin3d is called to perform
C     line minimizations. AH is the Hueckel adjacency matrix of atoms.
C     Parameters: NMAX is the maximum anticipated value of n; ITMAX is the maximum allowed
C     number of iterations; EPS is a small number to rectify special case of converging to exactly
C     zero function value.
C     USES dfunc2d,func2d,linmin2d
C     func3d input vector p of length n user defined to be optimized
C     IOP=1: spring embedding
C     IOP=2: spring + Coulomb embedding
C     IOP=3: Pisanski-Plestenjak-Graovac algorithm
C     IOP=4: Kamada-Kawai embedding

      iter=0
      CALL func2d(IOP,AH,IS,MDist,maxd,p,fp,RAA)
       E0=fp
      Write(Iout,1003) E0
C     dfunc3d input vector p of length 2*number_vertices, output gradient of length 2*number_vertices user defined
      CALL dfunc2d(IOP,AH,IS,MDist,maxd,p,xi,RAA)
      grad2=0.d0
      do I=1,2*number_vertices
       grad2=grad2+xi(i)*xi(i)
      enddo
      grad=dsqrt(grad2)
      Write(Iout,1001) iter,fp-E0,grad
      if(grad.lt.ftol) return
      do j=1,2*number_vertices
        g(j)=-xi(j)
        h(j)=g(j)
        xi(j)=h(j)
      enddo
        fret=0.d0
      do its=1,ITMAX
        iter=its
        call linmin2d(IOP,Iout,AH,IS,MDist,maxd,
     1       p,pcom,xi,xicom,fret,RAA)
         grad2=0.d0
         do I=1,2*number_vertices
          grad2=grad2+xi(i)*xi(i)
         enddo
         grad=dsqrt(grad2)
        Write(Iout,1001) iter,fret-E0,grad
        if(2.d0*dabs(fret-fp).le.ftol*(dabs(fret)+dabs(fp)+EPS))then
          Write(Iout,1002) fret-E0,fret-fp
          return
        endif
        fp=fret
        CALL dfunc2d(IOP,AH,IS,MDist,maxd,p,xi,RAA)
        gg=0.d0
        dgg=0.d0
        do j=1,2*number_vertices
          gg=gg+g(j)**2
C         dgg=dgg+xi(j)**2
          dgg=dgg+(xi(j)+g(j))*xi(j)
        enddo
        if(gg.eq.0.d0)return
        gam=dgg/gg
        do j=1,2*number_vertices
          g(j)=-xi(j)
          h(j)=g(j)+gam*h(j)
          xi(j)=h(j)
        enddo   
      enddo
      Write(Iout,1000) fret,fret-fp
 1000 Format(' WARNING: Subroutine frprmn2d: maximum iterations
     1 exceeded',/1X,'energy ',F15.9,', diff= ',D12.3)
 1001 Format(' Iteration ',I4,', energy ',D14.8,', gradient ',D14.8)
 1002 Format(/1X,'Convergence achieved, energy ',F20.7,', diff= ',D12.3)
 1003 Format(/1X,'E0= ',D12.3)
      return
      END

      SUBROUTINE linmin2d(IOP,Iout,AH,IS,MDist,
     1 maxd,p,pcom,xi,xicom,fret,RAA)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      REAL*8 p(NMAX*2),pcom(NMAX*2),xicom(NMAX*2),xi(NMAX*2)
      Integer AH(NMAX,NMAX),IS(6),MDist(NMAX,NMAX)
      PARAMETER (TOL=1.d-8)
C     USES brent2d,f1dim2d,mnbrak2d
      do j=1,2*number_vertices
        pcom(j)=p(j)
        xicom(j)=xi(j)
      enddo
      ax=0.d0
      xx=1.d0
      CALL mnbrak2d(IOP,Iout,AH,IS,MDist,maxd,
     1 ax,xx,bx,fa,fx,fb,xicom,pcom,RAA)
      CALL brent2d(IOP,Iout,AH,IS,MDist,maxd,
     1 fret,ax,xx,bx,TOL,xmin,xicom,pcom,RAA)
      do j=1,2*number_vertices
        xi(j)=xmin*xi(j)
        p(j)=p(j)+xi(j)
      enddo
      return
      END

      SUBROUTINE f1dim2d(IOP,A,IS,MDist,maxd,
     1 f1dimf,x,xicom,pcom,RAA)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      REAL*8 pcom(NMAX*2),xt(NMAX*2),xicom(NMAX*2)
      Integer A(NMAX,NMAX),IS(6),MDist(NMAX,NMAX)
C     USES func2d
      do j=1,2*number_vertices
        xt(j)=pcom(j)+x*xicom(j)
      enddo
      CALL func2d(IOP,A,IS,MDist,maxd,xt,f1dimf,RAA)
      return
      END

      SUBROUTINE mnbrak2d(IOP,Iout,AH,IS,DD,maxd,
     1 ax,bx,cx,fa,fb,fc,xicom,pcom,RAA)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (GOLD=1.618034d0,GLIMIT=1.d2,TINY=1.d-20)
      Integer AH(NMAX,NMAX),IS(6)
      Integer DD(NMAX,NMAX)
      REAL*8 pcom(NMAX*2),xicom(NMAX*2)
      CALL f1dim2d(IOP,AH,IS,DD,maxd,fa,ax,xicom,pcom,
     1 RAA)
      CALL f1dim2d(IOP,AH,IS,DD,maxd,fb,bx,xicom,pcom,
     1 RAA)
      if(fb.gt.fa)then
        dum=ax
        ax=bx
        bx=dum
        dum=fb
        fb=fa
        fa=dum
      endif
      cx=bx+GOLD*(bx-ax)
      CALL f1dim2d(IOP,AH,IS,DD,maxd,fc,cx,xicom,pcom,
     1 RAA)
1     if(fb.ge.fc)then
        r=(bx-ax)*(fb-fc)
        q=(bx-cx)*(fb-fa)
        u=bx-((bx-cx)*q-(bx-ax)*r)/(2.*sign(max(dabs(q-r),TINY),q-r))
        ulim=bx+GLIMIT*(cx-bx)
        if((bx-u)*(u-cx).gt.0.)then
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1 RAA)
          if(fu.lt.fc)then
            ax=bx
            fa=fb
            bx=u
            fb=fu
            return
          else if(fu.gt.fb)then
            cx=u
            fc=fu
            return
          endif
          u=cx+GOLD*(cx-bx)
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1 RAA)
        else if((cx-u)*(u-ulim).gt.0.)then
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1 RAA)
          if(fu.lt.fc)then
            bx=cx
            cx=u
            u=cx+GOLD*(cx-bx)
            fb=fc
            fc=fu
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1 RAA)
          endif
        else if((u-ulim)*(ulim-cx).ge.0.)then
          u=ulim
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1 RAA)
        else
          u=cx+GOLD*(cx-bx)
        if(u.gt.1.d10) then
        Write(Iout,1000)
        return
        endif
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1 RAA)
        endif
        ax=bx
        bx=cx
        cx=u
        fa=fb
        fb=fc
        fc=fu
        goto 1
      endif
      return
 1000 Format('**** Error in Subroutine mnbrak2d')
      END

      SUBROUTINE brent2d(IOP,Iout,AH,IS,DD,maxd,
     1 fx,ax,bx,cx,tol,xmin,xicom,pcom,RAA)
      use config
C BRENT is a FORTRAN library which contains algorithms for finding zeros 
C or minima of a scalar function of a scalar variable, by Richard Brent. 
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (ITMAX=500,CGOLD=.3819660,ZEPS=1.d-10)
      REAL*8 pcom(NMAX*2),xicom(NMAX*2)
      Integer AH(NMAX,NMAX),IS(6)
      Integer DD(NMAX,NMAX)
      a=min(ax,cx)
      b=max(ax,cx)
      v=bx
      w=v
      x=v
      e=0.d0
      CALL f1dim2d(IOP,AH,IS,DD,maxd,fx,x,xicom,pcom,
     1 RAA)
      fv=fx
      fw=fx
      do 11 iter=1,ITMAX
        xm=0.5d0*(a+b)
        tol1=tol*dabs(x)+ZEPS
        tol2=2.d0*tol1
        if(dabs(x-xm).le.(tol2-.5d0*(b-a))) goto 3
        if(dabs(e).gt.tol1) then
          r=(x-w)*(fx-fv)
          q=(x-v)*(fx-fw)
          p=(x-v)*q-(x-w)*r
          q=2.d0*(q-r)
          if(q.gt.0.) p=-p
          q=abs(q)
          etemp=e
          e=d
          if(dabs(p).ge.abs(.5d0*q*etemp).or.p.le.q*(a-x).
     1      or.p.ge.q*(b-x)) goto 1
          d=p/q
          u=x+d
          if(u-a.lt.tol2 .or. b-u.lt.tol2) d=sign(tol1,xm-x)
          goto 2
        endif
1       if(x.ge.xm) then
          e=a-x
        else
          e=b-x
        endif
        d=CGOLD*e
2       if(dabs(d).ge.tol1) then
          u=x+d
        else
          u=x+sign(tol1,d)
        endif
        CALL f1dim2d(IOP,AH,IS,DD,maxd,fu,u,xicom,pcom,
     1    RAA)
        if(fu.le.fx) then
          if(u.ge.x) then
            a=x
          else
            b=x
          endif
          v=w
          fv=fw
          w=x
          fw=fx
          x=u
          fx=fu
        else
          if(u.lt.x) then
            a=u
          else
            b=u
          endif
          if(fu.le.fw .or. w.eq.x) then
            v=w
            fv=fw
            w=u
            fw=fu
          else if(fu.le.fv .or. v.eq.x .or. v.eq.w) then
            v=u
            fv=fu
          endif
        endif
11    continue
      Write(Iout,1000)
 1000 Format('WARNING: Subroutine brent2d: maximum iterations exceeded')
3     xmin=x
      return
      END

      SUBROUTINE OptFF(Iout,ihessian,iprinthessian,iopt,IDA,
     1  Dist,dist2D,ftol,force)
      use config
      use iso_c_binding
      IMPLICIT REAL*8 (A-H,O-Z)
C  This subroutine optimizes the fullerene 3D structure using a force field
c  (e.g. the Wu force field):  Z. C. Wu, D. A. Jelski, T. F. George, "Vibrational
c  Motions of Buckminsterfullerene", Chem. Phys. Lett. 137, 291-295 (1987).
C  Angstroem and rad is used for bond distances and bond length
C  Data from Table 1 of Wu in dyn/cm = 10**-3 N/m
      DIMENSION Dist(3,NMAX)
      DIMENSION IDA(NMAX,NMAX)
      real(8) force(ffmaxdim)
      integer iopt,ideg(number_vertices*3)
      real(8) hessian(number_vertices*3,number_vertices*3),
     1 evec(number_vertices*3),df(number_vertices*3)
      type(c_ptr) :: graph, new_fullerene_graph

c edges with 0, 1, 2 pentagons
      integer e_hh(2,3*number_vertices/2), e_hp(2,3*number_vertices/2),
     1  e_pp(2,3*number_vertices/2)
      integer a_h(3,3*number_vertices-60), a_p(3,60)
      integer d_hhh(4,number_vertices), d_hpp(4,number_vertices),
     1  d_hhp(4,number_vertices), d_ppp(4,number_vertices)
c counter for edges with 0, 1, 2 pentagons neighbours
      integer ne_hh,ne_hp,ne_pp
      integer nd_hhh,nd_hhp,nd_hpp,nd_ppp

      graph = new_fullerene_graph(Nmax,number_vertices,IDA)
      call tutte_layout(graph,Dist2D)
      call set_layout2d(graph,Dist2D)
      call get_edges(graph,number_vertices,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp)
      call get_corners(graph,number_vertices,
     1 a_h,a_p)
      if(iopt .eq. 3 .or. iopt.eq.4) then
        call get_dihedrals(graph,number_vertices,
     1   d_hhh,d_hhp,d_hpp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      endif
c     and finally delete the graph to free the mem
      call delete_fullerene_graph(graph)     

      select case(iopt)
      case(1)
        Write(IOUT,1000)
        Write(Iout,1016) ftol,(force(i),i=1,8)
      case(2)
        Write(IOUT,1000)
        Write(Iout,1019) ftol,(force(i),i=1,9)
      case(3)
        Write(IOUT,1007)
        Write(Iout,1020) ftol,(force(i),i=1,18)
      case(4)
        Write(IOUT,1007)
        Write(Iout,1018) ftol,(force(i),i=1,19)
      end select
C       Conversion to kJ/mol
C       energies in KJ/mol, gradients in kJ/mol/A and hessian kJ/mol/A^2
        unitconv=1.d-20 * 6.02214129d20
      if(iopt.eq.1 .or. iopt.eq.2)then
c        force(1)=force(1)
c        force(2)=force(2)
C       Conversion of angles in rad
        force(3)=force(3)*deg2rad
        force(4)=force(4)*deg2rad
        force(5)=force(5)*unitconv
        force(6)=force(6)*unitconv
        force(7)=force(7)*unitconv
        force(8)=force(8)*unitconv
C       Leave parameter for Coulomb force as it is
c        force(9)=force(9)
      else if (iopt.eq.3 .or. iopt.eq.4) then
c        force(1)=force(1)
c        force(2)=force(2)
c        force(3)=force(3)
C       Conversion of angles and dihedrals in rad
        force(4)=force(4)*deg2rad
        force(5)=force(5)*deg2rad
        force(6)=force(6)*deg2rad
        force(7)=force(7)*deg2rad
        force(8)=force(8)*deg2rad
        force(9)=force(9)*deg2rad
C       Conversion of dyn/cm in a.u. / Angstroem**2
        force(10)=force(10)*unitconv
        force(11)=force(11)*unitconv
        force(12)=force(12)*unitconv
        force(13)=force(13)*unitconv
        force(14)=force(14)*unitconv
        force(15)=force(15)*unitconv
        force(16)=force(16)*unitconv
        force(17)=force(17)*unitconv
        force(18)=force(18)*unitconv
C       Leave parameter for Coulomb force as it is
c        force(19)=force(19)
      end if
      select case(iopt)
      case(1)
        Write(Iout,1006) (force(i),i=1,8)
      case(2)
        Write(Iout,1003) (force(i),i=1,9)
      case(3)
        Write(Iout,1005) (force(i),i=1,18)
      case(4)
        Write(Iout,1008) (force(i),i=1,19)
      end select
      if(iopt.eq.2 .and. force(9).gt.0.d0) Write(Iout,1004) force(9)

C OPTIMIZE
      CALL frprmn3d(Iout,
     1 Dist,force,iopt,ftol,iter,fret,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      if(fret.gt.1.d-2) then
        fretn=fret/dfloat(number_vertices)
        Write(IOUT,1002) fretn
      endif
      CALL Distan(IDA,Dist,Rmin,Rminall,Rmax,rms)
      Write(IOUT,1001) Rmin,Rmax,rms

C HESSIAN
      if(ihessian.ne.0) then
        call get_hessian(dist, force, iopt, hessian,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hhp,d_hpp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        if(iprinthessian.gt.1) then
          write(iout,1023)
          write(iout,1024)
     1      ((hessian(i,j),i=1,3*number_vertices),j=1,3*number_vertices)
        endif
C Diagonalize without producing eigenvectors
C  Mass of 12-C used
        amassC=12.0d0
        fachess=3.80879844d-4/amassC
        convw=2720.21d0
C       Test if Hessian is symmetric
        symmetric=0.d0
        test=1.d-10
        do i=1,3*number_vertices
          do j=1,3*number_vertices
            symmetric=symmetric+dabs(hessian(i,j)-hessian(j,i))
          enddo
        enddo
        asym=symmetric*.5d0
        if(asym.gt.test) then
          Write(Iout,1013) asym
        else
          Write(Iout,1015) asym
        endif
C       Mass-weight Hessian
        do i=1,3*number_vertices
          do j=1,3*number_vertices
            hessian(i,j)=hessian(i,j)*fachess
          enddo
        enddo
        call tred2l(hessian,3*number_vertices,3*number_vertices,evec,df)
        call tqlil(evec,df,3*number_vertices,3*number_vertices)
C Sort eigenvalues
        negeig=0
        Do I=1,number_vertices*3
          e0=evec(I)
          jmax=I
          Do J=I+1,number_vertices*3
            e1=evec(J)
            if(e1.gt.e0) then
              jmax=j
              e0=e1
            endif
          enddo
          if(i.ne.jmax) then
            ex=evec(jmax)
            evec(jmax)=evec(I)
            evec(I)=ex
          endif
        enddo
        if(iprinthessian.ne.0) then
          write(Iout,1009)
          write(Iout,1010) (evec(i),i=1,3*number_vertices)
        endif
        Do I=1,number_vertices*3
          if(evec(i).lt.0.d0) then
            negeig=negeig+1
            evec(i)=-dsqrt(-evec(i))
          else
            evec(i)=dsqrt(evec(i))
          endif
        enddo
        write(Iout,1011) negeig
        Do I=1,number_vertices*3
          evec(i)=evec(i)*convw
        enddo
        if(iprinthessian.ne.0) then
          write(Iout,1012)
          write(Iout,1010) (evec(i),i=1,number_vertices*3)
        endif
C Zero-point vibrational energy
        zerops=0.d0
        Do I=1,number_vertices*3-6
          zerops=zerops+evec(i)
        enddo
        zerop=zerops*.5d0
        zeropwn=zerop
        zeropau=zerop/au2wavenumbers
        zeropeV=zeropau*au2eV
        peratom=dfloat(number_vertices)
        write(Iout,1014) zeropau,zeropeV,zeropwn
        write(Iout,1026) zeropau/peratom,zeropeV/peratom,zeropwn/peratom
C Sort for degeneracies
        tolfreq=1.d-1
        icount=0
        idegc=0
        ndeg=0
        Do I=1,number_vertices*3-6
          idegc=idegc+1
          dif=evec(i)-evec(i+1)
          if(dif.gt.tolfreq) then
            icount=icount+1
            evec(icount)=evec(i)
            ideg(icount)=idegc
            ndeg=ndeg+idegc
            idegc=0
          endif
        enddo
        write(Iout,1021) ndeg,number_vertices*3-6
        write(Iout,1022) (evec(i),ideg(i),i=1,icount)
        write(Iout,1025)
     1    (evec(i),i=number_vertices*3-5,3*number_vertices)
      endif

 1000 Format(1X,'Optimization of geometry using harmonic oscillators',
     1 ' for stretching and bending modes using the force-field of',
     1 ' Wu et al.',/1X,'Fletcher-Reeves-Polak-Ribiere algorithm used')
 1001 FORMAT(1X,'Minimum distance: ',F12.6,', Maximum distance: ',F12.6,
     1 ', RMS distance: ',F12.6)
 1002 FORMAT(1X,'Distances and angles defined in the force field can',
     1 ' not be reached',/1X,'Energy per atom in atomic units: ',F12.6)
 1003 Format(' Force field parameters in au/A^2 and au/rad^2:',
     1 /1X,9F12.6,/)
 1004 Format(' Coulomb repulsion from center of origin with force ',
     1 F12.6,/)
 1005 Format(' Force field parameters in au/A^2 and au/rad^2:',
     1 /1X,18F12.6,/)
 1006 Format(' Force field parameters in au/A^2 and au/rad^2:',
     1 /1X,8F12.6,/)
 1007 Format(1X,'Optimization of geometry using harmonic oscillators',
     1 ' for stretching and bending modes using an extension of the',
     1 ' force-field of Wu et al.',/1X,'Fletcher-Reeves-Polak-Ribiere',
     1 ' algorithm used')
 1008 Format(' Force field parameters in au/A^2 and au/rad^2:',
     1 /1X,19F12.6,/)
 1009 Format(' Eigenvalues of mass-weighted Hessian:')
 1010 Format(10(1X,D12.6))
 1011 Format(' Number of zero and negative eigenvalues: ',I6)
 1012 Format(' Frequencies (cm-1):')
 1013 Format(' Severe problem. Hessian is not symmetric: asym= ',d12.6)
 1014 Format(' Zero-point vibrational energy: ',d12.6,' a.u. , ',
     1 d12.6,' eV , ',d12.6,' cm-1 , ')
 1015 Format(' Hessian is symmetric: asym= ',d12.6)
 1016 Format(' Tolerance= ',D9.3,', Force field parameters in ',
     1 'A, deg, N/m:',/1X,8F12.3)
 1018 Format(' Tolerance= ',D9.3,', Force field parameters in ',
     1 'A, deg, N/m:'/1X,19F12.2)
 1019 Format(' Tolerance= ',D9.3,', Force field parameters in ',
     1 'A, deg, N/m:'/1X,9F12.2)
 1020 Format(' Tolerance= ',D9.3,', Force field parameters in ',
     1 'A, deg, N/m:'/1X,18F12.2)
 1021 Format(1X,I6,' non-zero frequencies (should be ',I6,').',
     1 ' Frequencies (in cm-1) and (quasi) degeneracies (n):')
 1022 Format(10(' ',f7.1,'(',I2,')'))
 1023 Format(' Hessian matrix:')
 1024 Format(8(d12.6,' '))
 1025 Format(' Zero frequencies for translation and rotation: ',
     1 6(d12.6,' '))
 1026 Format(' Zero-point vibrational energy per atom: ',d12.6,
     1 ' a.u. , ',d12.6,' eV , ',d12.6,' cm-1 , ')
     
      Return 
      END

      SUBROUTINE frprmn3d(Iout,
     1 p,force,iopt,ftol,iter,fret,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (ITMAX=99999,EPS=1.d-9)
      Real*8 p(NMAX*3),g(NMAX*3),h(NMAX*3),xi(NMAX*3)
      Real*8 pcom(NMAX*3),xicom(NMAX*3)
      real*8 force(ffmaxdim)
      integer iopt

C     Given a starting point p that is a vector of length n, Fletcher-Reeves-Polak-Ribiere minimization
C     is performed on a function func3d, using its gradient as calculated by a routine dfunc3d.
C     The convergence tolerance on the function value is input as ftol. Returned quantities are
C     p (the location of the minimum), iter (the number of iterations that were performed),
C     and fret (the minimum value of the function). The routine linmin3d is called to perform
C     line minimizations. AH is the Hueckel adjacency matrix of atoms.
C     Parameters: NMAX is the maximum anticipated value of n; ITMAX is the maximum allowed
C     number of iterations; EPS is a small number to rectify special case of converging to exactly
C     zero function value.
C     USES dfunc3d,func3d,linmin3d
C     func3d input vector p of length n user defined to be optimized
C     IOPT=1: Wu force field optimization
      iter=0
      CALL func3d(IERR,p,fp,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      if(IERR.ne.0) then
        Write(Iout,1004)
        return
      endif
C     dfunc3d input vector p of length N, output gradient of length n user defined
      CALL dfunc3d(p,xi,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      grad2=0.d0
      do I=1,3*number_vertices
        grad2=grad2+xi(i)*xi(i)
      enddo
      grad=dsqrt(grad2)
      Write(Iout,1001) iter,fp,grad
      if(grad.lt.ftol) return
      do j=1,3*number_vertices
        g(j)=-xi(j)
        h(j)=g(j)
        xi(j)=h(j)
      enddo
      fret=0.d0
      do its=1,ITMAX
c       turn off coulomb pot towards the end (and go to iopt=3 to indicate that coulomb has been shut of)
        if(iopt.eq.4 .and. force(19).gt.0.d0 .and. grad.le.1.d1) then
          force(19)=0.0d0
          iopt=3
          write(*,*)'Switching off coulomb repulsive potential.'
        endif
        iter=its
        call linmin3d(p,pcom,xi,xicom,fret,
     1    force,iopt,e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1    a_h,a_p,
     1    d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        grad2=0.d0
        do I=1,3*number_vertices
          grad2=grad2+xi(i)*xi(i)
        enddo
        grad=dsqrt(grad2)
c        if(damping.eq.0) then 
          write(Iout,1001) iter,fret,grad
c        else
c          write(Iout,1002) iter,fret,grad,damping
c        endif
        if(2.d0*dabs(fret-fp).le.ftol*(dabs(fret)+dabs(fp)+EPS))then
          fretperatom=3.d0*fret/dfloat(3*number_vertices)
          Write(Iout,1003) fret,fret-fp,fretperatom
          return
        endif
        fp=fret
        CALL dfunc3d(p,xi,force,iopt,
     1    e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1    a_h,a_p,
     1    d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        gg=0.d0
        dgg=0.d0
        do j=1,3*number_vertices
          gg=gg+g(j)**2
C         dgg=dgg+xi(j)**2
          dgg=dgg+(xi(j)+g(j))*xi(j)
        enddo
        if(gg.eq.0.d0)return
        gam=dgg/gg
        do j=1,3*number_vertices
          g(j)=-xi(j)
          h(j)=g(j)+gam*h(j)
          xi(j)=h(j)
        enddo   
      enddo
      Write(Iout,1000) fret,fret-fp
 1000 Format(' WARNING: Subroutine frprmn3d: maximum iterations
     1 exceeded',/1X,'energy ',F15.9,', diff= ',D12.3)
 1001 Format(' Iteration ',I6,', energy [kJ/mol] ',D14.8,
     1 ', gradient [kJ/mol/A] ',D14.8)
c 1002 Format(' Iteration ',I6,', energy ',D14.8,', gradient ',D14.8,
c     1 ' The displacements of ',I4,' atoms were damped.')
 1003 Format(/1X,'Convergence achieved, energy [kJ/mol] ',D14.8,
     1 ', diff= ',D12.3,/1X,'Energy per atom [kJ/mol]: ',D14.8)
 1004 Format('**** Severe error in angle, check input coordiantes:',
     1 ' One angle either 0 or 180 degrees, ill-alligned structure',
     1 /1X,'Cannot optimize structure, check eigenvector input')
      return
      END

      SUBROUTINE linmin3d(p,pcom,xi,xicom,fret,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)!,damping)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      REAL*8 p(NMAX*3),pcom(NMAX*3),xicom(NMAX*3),xi(NMAX*3)
      PARAMETER (TOL=1.d-5)
c      real*8 length, cutoff, xi_tmp(nmax*3)
c      integer damping
C     USES brent3d,f1dim3d,mnbrak3d
      do j=1,3*number_vertices
        pcom(j)=p(j)
        xicom(j)=xi(j)
      enddo
      ax=0.d0
      xx=1.d0
      CALL mnbrak3d(
     1 ax,xx,bx,fa,fx,fb,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      CALL brent3d(Iout,fret,
     1 ax,xx,bx,TOL,xmin,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
c lets scale all displacements that are longer than a chosen cutoff to that cutoff.
c the direction of the displacement vector is maintained
      do j=1,3*number_vertices
        xi(j)=xmin*xi(j)
c        xi_tmp(j)=xi(j)
      enddo
c larger cutoffs result in faster convergence and are less safe ...
c      cutoff=3.0d1
c     count the number of atoms/displacements that were damped
c      damping=0
c      do j=1,n,3
c        length=dsqrt(xi(j)*xi(j) + xi(j+1)*xi(j+1) + xi(j+2)*xi(j+2))
c        if (length .gt. cutoff) then
c          xi_tmp(j)  =xi_tmp(j)  *(cutoff/length)
c          xi_tmp(j+1)=xi_tmp(j+1)*(cutoff/length)
c          xi_tmp(j+2)=xi_tmp(j+2)*(cutoff/length)
c          damping=damping + 1
c        endif
c      enddo
      do j=1,3*number_vertices
c        p(j)=p(j)+xi_tmp(j)
        p(j)=p(j)+xi(j)
      enddo
      return
      END

      SUBROUTINE f1dim3d(
     1 f1dimf,x,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      REAL*8 pcom(NMAX*3),xt(NMAX*3),xicom(NMAX*3)
C     USES func3d
      do j=1,3*number_vertices
        xt(j)=pcom(j)+x*xicom(j)
      enddo
      CALL func3d(IERR,xt,f1dimf,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      return
      END

      SUBROUTINE mnbrak3d(
     1 ax,bx,cx,fa,fb,fc,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (GOLD=1.618034d0,GLIMIT=1.d2,TINY=1.d-20)
      REAL*8 pcom(NMAX*3),xicom(NMAX*3)
      CALL f1dim3d(
     1 fa,ax,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      CALL f1dim3d(
     1 fb,bx,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      if(fb.gt.fa)then
        dum=ax
        ax=bx
        bx=dum
        dum=fb
        fb=fa
        fa=dum
      endif
      cx=bx+GOLD*(bx-ax)
      CALL f1dim3d(
     1 fc,cx,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
1     if(fb.ge.fc)then
        r=(bx-ax)*(fb-fc)
        q=(bx-cx)*(fb-fa)
        u=bx-((bx-cx)*q-(bx-ax)*r)/(2.*sign(max(dabs(q-r),TINY),q-r))
        ulim=bx+GLIMIT*(cx-bx)
        if((bx-u)*(u-cx).gt.0.)then
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
          if(fu.lt.fc)then
            ax=bx
            fa=fb
            bx=u
            fb=fu
            return
          else if(fu.gt.fb)then
            cx=u
            fc=fu
            return
          endif
          u=cx+GOLD*(cx-bx)
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        else if((cx-u)*(u-ulim).gt.0.)then
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
          if(fu.lt.fc)then
            bx=cx
            cx=u
            u=cx+GOLD*(cx-bx)
            fb=fc
            fc=fu
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
          endif
        else if((u-ulim)*(ulim-cx).ge.0.)then
          u=ulim
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     2   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        else
          u=cx+GOLD*(cx-bx)
        if(u.gt.1.d10) then
        Print*,'**** Error in Subroutine mnbrak3d'
        return
        endif
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        endif
        ax=bx
        bx=cx
        cx=u
        fa=fb
        fb=fc
        fc=fu
        goto 1
      endif
      return
      END

      SUBROUTINE brent3d(Iout,
     1 fx,ax,bx,cx,tol,xmin,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      use config
C BRENT is a FORTRAN library which contains algorithms for finding zeros 
C or minima of a scalar function of a scalar variable, by Richard Brent. 
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (ITMAX=500,CGOLD=.3819660,ZEPS=1.d-10)
      REAL*8 pcom(NMAX*3),xicom(NMAX*3)
      a=min(ax,cx)
      b=max(ax,cx)
      v=bx
      w=v
      x=v
      e=0.d0
      CALL f1dim3d(
     1 fx,x,xicom,pcom,force,iopt,
     1 e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1 a_h,a_p,
     1 d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      fv=fx
      fw=fx
      do 11 iter=1,ITMAX
        xm=0.5d0*(a+b)
        tol1=tol*dabs(x)+ZEPS
        tol2=2.d0*tol1
        if(dabs(x-xm).le.(tol2-.5d0*(b-a))) goto 3
        if(dabs(e).gt.tol1) then
          r=(x-w)*(fx-fv)
          q=(x-v)*(fx-fw)
          p=(x-v)*q-(x-w)*r
          q=2.d0*(q-r)
          if(q.gt.0.) p=-p
          q=abs(q)
          etemp=e
          e=d
          if(dabs(p).ge.abs(.5d0*q*etemp).or.p.le.q*(a-x).
     1      or.p.ge.q*(b-x)) goto 1
          d=p/q
          u=x+d
          if(u-a.lt.tol2 .or. b-u.lt.tol2) d=sign(tol1,xm-x)
          goto 2
        endif
1       if(x.ge.xm) then
          e=a-x
        else
          e=b-x
        endif
        d=CGOLD*e
2       if(dabs(d).ge.tol1) then
          u=x+d
        else
          u=x+sign(tol1,d)
        endif
        CALL f1dim3d(
     1   fu,u,xicom,pcom,force,iopt,
     1   e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1   a_h,a_p,
     1   d_hhh,d_hpp,d_hhp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
        if(fu.le.fx) then
          if(u.ge.x) then
            a=x
          else
            b=x
          endif
          v=w
          fv=fw
          w=x
          fw=fx
          x=u
          fx=fu
        else
          if(u.lt.x) then
            a=u
          else
            b=u
          endif
          if(fu.le.fw .or. w.eq.x) then
            v=w
            fv=fw
            w=u
            fw=fu
          else if(fu.le.fv .or. v.eq.x .or. v.eq.w) then
            v=u
            fv=fu
          endif
        endif
11    continue
      Write(Iout,1000)
 1000 Format(' WARNING: Subroutine brent3d: maximum iterations
     1 exceeded')
3     xmin=x
      return
      END

      SUBROUTINE powell(n,iter,Iout,IOP,ier,ftol,AN,RMDSI,p,pmax,Dist)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (ITMAX=20,TINY=1.D-20)
      REAL*8 p(n),pcom(n),xicom(n),xi(n,n),pt(n),ptt(n),xit(n),step(n)
      REAL*8 Dist(3,Nmax),pmax(n)
      
c numerical recipies cluster to do Powell minimization
c
c   p(n)      ... initial starting point (input); best point (output)
c   xi(n,n)   ... matrix containing the initial set of directions (input)
c   n         ... dimension; number of variables (input)
c   ftol      ... fractional tolerance in the function value (input)
c   iter      ... number of iterations taken
c   fret      ... value of f at p
      iter=0
      ier=0
      TOL=ftol
      If(IOP.eq.0) then
       call MDSnorm(n,fret,RMDSI,p,Dist)
      else
       call MAInorm(n,IP,AN,p,Dist)
       fret=-AN
      endif
      WRITE(IOUT,1002)
      WRITE(IOUT,1005) ftol,n
      do j=1,n
       step(j)=0.1d0
       pt(j)=p(j)
      enddo
      WRITE(IOUT,1006) (p(j),j=1,n),fret
        do i=1,n
        do j=1,i
          xi(j,i)=0.d0
          xi(i,j)=0.d0
          if(i.eq.j) xi(i,i)=step(i)
        enddo
        enddo
1     iter=iter+1
      fp=fret
      ibig=0
      del=0.d0
      do 13 i=1,n
        do 12 j=1,n
          xit(j)=xi(j,i)
12      continue
        fptt=fret
        call linminx(n,IOP,ier,TOL,p,xit,fret,pcom,xicom,Dist)
          if(ier.eq.1) Return
        if(dabs(fptt-fret).gt.del)then
          del=dabs(fptt-fret)
          ibig=i
        endif
13    continue
        WRITE(IOUT,1004) iter,(p(j),j=1,3),fret
      If(IOP.eq.0) then
       if(dabs(p(1)).gt.pmax(1)) ier=2
       if(dabs(p(2)).gt.pmax(2)) ier=2
       if(dabs(p(3)).gt.pmax(3)) ier=2
       if(ier.eq.2) return
      endif
      if(2.*dabs(fp-fret).le.ftol*(dabs(fp)+dabs(fret))+TINY) Return
      if(iter.eq.ITMAX) Go to 2
      do 14 j=1,n
        ptt(j)=2.*p(j)-pt(j)
        xit(j)=p(j)-pt(j)
        pt(j)=p(j)
14    continue
      If(IOP.eq.0) then
       Call MDSnorm(n,fptt,RMDSI,ptt,Dist)
      else
       Call MAInorm(n,IP,AN,ptt,Dist)
       fptt=-AN
      endif
      if(fptt.ge.fp)goto 1
      t=2.*(fp-2.*fret+fptt)*(fp-fret-del)**2-del*(fp-fptt)**2
      if(t.ge.0.)goto 1
      call linminx(n,IOP,ier,TOL,p,xit,fret,pcom,xicom,Dist)
      if(ier.eq.1) Return
      do 15 j=1,n
        xi(j,ibig)=xi(j,n)
        xi(j,n)=xit(j)
15    continue
      goto 1
 2    WRITE(IOUT,1007)
 1002 FORMAT(/1x,'Start Powell optimization')
 1004 FORMAT(' Iter: ',I6,' C(S): ',3(D14.8,1X)' Norm: ',D14.8)
 1005 Format(' Fractional tolerance ftol = ',D12.5,
     * ', dimension of problem n = ',i1)
 1006 FORMAT(' Start:       C(S): ',3(D14.8,1X),' Norm: ',D14.8)
 1007 Format(' WARNING: Optimizer Powell exceeding maximum iterations')
      Return
      END

      SUBROUTINE linminx(n,IOP,ier,
     1 TOL,p,xi,fret,pcom,xicom,Dist)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      REAL*8 p(n),xi(n),pcom(n),xicom(n)
      REAL*8 Dist(3,Nmax)
CU    USES brentx,f1dimx,mnbrakx
      do 11 j=1,n
        pcom(j)=p(j)
        xicom(j)=xi(j)
11    continue
      ax=0.d0
      xx=1.d0
      call mnbrakx(n,IOP,ier,
     1 pcom,xicom,ax,xx,bx,fa,fx,fb,Dist)
      if(ier.eq.1) Return
      fret=brentx(n,IOP,ier,pcom,xicom,ax,xx,bx,TOL,xmin,Dist)
      do 12 j=1,n
        xi(j)=xmin*xi(j)
        p(j)=p(j)+xi(j)
12    continue
      return
      END

      SUBROUTINE mnbrakx(ncom,IOP,ier,pcom,xicom,ax,bx,cx,
     1 fa,fb,fc,Dist)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (GOLD=1.618034d0,GLIMIT=1.d2,TINY=1.d-20,HUGE=1.d10)
      REAL*8 pcom(ncom),xicom(ncom)
      REAL*8 Dist(3,Nmax)
      fa=f1dimx(ncom,IOP,ier,ax,pcom,xicom,Dist)
      fb=f1dimx(ncom,IOP,ier,bx,pcom,xicom,Dist)
      if(fb.gt.fa)then
        dum=ax
        ax=bx
        bx=dum
        dum=fb
        fb=fa
        fa=dum
      endif
      cx=bx+GOLD*(bx-ax)
      fc=f1dimx(ncom,IOP,ier,cx,pcom,xicom,Dist)
1     if(fb.ge.fc)then
        r=(bx-ax)*(fb-fc)
        q=(bx-cx)*(fb-fa)
        if(ax.gt.HUGE.or.bx.gt.HUGE.or.CX.gt.HUGE) then
         ier=1
         Return
         endif
        u=bx-((bx-cx)*q-(bx-ax)*r)/(2.*sign(max(dabs(q-r),TINY),q-r))
        ulim=bx+GLIMIT*(cx-bx)
        if((bx-u)*(u-cx).gt.0.)then
          fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
          if(fu.lt.fc)then
            ax=bx
            fa=fb
            bx=u
            fb=fu
            return
          else if(fu.gt.fb)then
            cx=u
            fc=fu
            return
          endif
          u=cx+GOLD*(cx-bx)
          fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
        else if((cx-u)*(u-ulim).gt.0.d0)then
          fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
          if(fu.lt.fc)then
            bx=cx
            cx=u
            u=cx+GOLD*(cx-bx)
            fb=fc
            fc=fu
            fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
          endif
        else if((u-ulim)*(ulim-cx).ge.0.d0)then
          u=ulim
          fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
        else
          u=cx+GOLD*(cx-bx)
          fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
        endif
        ax=bx
        bx=cx
        cx=u
        fa=fb
        fb=fc
        fc=fu
        goto 1
      endif
      return
      END

      DOUBLE PRECISION FUNCTION brentx(ncom,IOP,ier,
     1 pcom,xicom,ax,bx,cx,tol,xmin,Dist)
      use config
      IMPLICIT REAL*8 (A-H,O-Z)
      REAL*8 Dist(3,Nmax)
      REAL*8 pcom(ncom),xicom(ncom)
      INTEGER ITMAX
      PARAMETER (ITMAX=1000,CGOLD=.3819660,ZEPS=1.D-10)
      a=min(ax,cx)
      b=max(ax,cx)
      v=bx
      w=v
      x=v
      e=0.
      fx=f1dimx(ncom,IOP,ier,x,pcom,xicom,Dist)
      fv=fx
      fw=fx
      do 11 iter=1,ITMAX
        xm=0.5*(a+b)
        tol1=tol*dabs(x)+ZEPS
        tol2=2.*tol1
        if(dabs(x-xm).le.(tol2-.5*(b-a))) goto 3
        if(dabs(e).gt.tol1) then
          r=(x-w)*(fx-fv)
          q=(x-v)*(fx-fw)
          p=(x-v)*q-(x-w)*r
          q=2.*(q-r)
          if(q.gt.0.) p=-p
          q=dabs(q)
          etemp=e
          e=d
          if(dabs(p).ge.dabs(.5*q*etemp).or.p.le.q*(a-x).or.
     * p.ge.q*(b-x)) goto 1
          d=p/q
          u=x+d
          if(u-a.lt.tol2 .or. b-u.lt.tol2) d=sign(tol1,xm-x)
          goto 2
        endif
1       if(x.ge.xm) then
          e=a-x
        else
          e=b-x
        endif
        d=CGOLD*e
2       if(dabs(d).ge.tol1) then
          u=x+d
        else
          u=x+sign(tol1,d)
        endif
        fu=f1dimx(ncom,IOP,ier,u,pcom,xicom,Dist)
        if(fu.le.fx) then
          if(u.ge.x) then
            a=x
          else
            b=x
          endif
          v=w
          fv=fw
          w=x
          fw=fx
          x=u
          fx=fu
        else
          if(u.lt.x) then
            a=u
          else
            b=u
          endif
          if(fu.le.fw .or. w.eq.x) then
            v=w
            fv=fw
            w=u
            fw=fu
          else if(fu.le.fv .or. v.eq.x .or. v.eq.w) then
            v=u
            fv=fu
          endif
        endif
11    continue
      Print*, 'WARNING: brent exceed maximum iterations'
3     xmin=x
      brentx=fx
      return
      END


C     Lukas: The following three subroutines iterate over
C      1. edges
C      2. corners
C      3. dihedrals
C     in linear time (i.e. constant time per element), while providing the information you asked for.
C
C     Assumptions: 
C     - g is a fullerene graph and has had a call to set_layout2d(g,layout2d) with its Tutte embedding as layout.
C       (or another strictly planar layout)
C     - N = Nvertices(g)
C     ------------------------------------------------------------
C                              EDGES
C     ------------------------------------------------------------
      SUBROUTINE get_edges(graph,N,
     1 edges_hh,edges_hp,edges_pp,na_hh,na_hp,na_pp)
      use iso_c_binding
      type(c_ptr) :: graph
      integer edges(2,3*N/2), faceA(6), faceB(6), NE, np, i, u, v, lA,lB
      integer edges_hh(2,3*N/2), edges_hp(2,3*N/2), edges_pp(2,3*N/2)
c     counter for edges with 0, 1, 2 pentagons neighbours
      integer na_hh,na_hp,na_pp
      na_hh=0
      na_hp=0
      na_pp=0

      do j=1,2
      do i=1,3*N/2
        edges_pp(j,i)=0
        edges_hp(j,i)=0
        edges_hh(j,i)=0
      enddo
      enddo
      call edge_list(graph,edges,NE)

      do i=1,NE
C       Edge u--v
        u = edges(1,i)
        v = edges(2,i)

C       Edge is part of how many pentagons?
        call get_arc_face(graph,u,v,faceA,lA) ! O(1) operation
        call get_arc_face(graph,v,u,faceB,lB) ! O(1) operation
        np = 12-lA-lB
         
C       Do what needs to be done to u--v here 
        select case(np)
        case(0)
          na_hh=na_hh+1
          edges_hh(1,na_hh)=u+1
          edges_hh(2,na_hh)=v+1
        case(1)
          na_hp=na_hp+1
          edges_hp(1,na_hp)=u+1
          edges_hp(2,na_hp)=v+1
        case(2)
          na_pp=na_pp+1
          edges_pp(1,na_pp)=u+1
          edges_pp(2,na_pp)=v+1
        case default
          write(*,*)'Something went horribly wrong: bond not adjacent ',
     1 'to 0, 1 or 2 pentagons'
          exit
        end select

c        write (*,*) "Edge ",(/u,v/)," connects ",np,"pentagons.",lA,lB 
      end do

      END SUBROUTINE

C     ------------------------------------------------------------
C                              CORNERS
C     ------------------------------------------------------------
      SUBROUTINE get_corners(graph,N,a_h,a_p)
c     here, n is the number of atoms
      use iso_c_binding
      type(c_ptr) :: graph
      integer pentagons(5,12), hexagons(6,N/2-10), u,v,w,i,j
c     arrays for atoms that are part of angles ... 
      integer a_p(3,60), a_h(3,3*n-60)
c     counter for angles around hexagons and pentagons
      integer NH

      NH = N/2-10

      call compute_fullerene_faces(graph,pentagons,hexagons) ! Yields faces with vertices ordered CCW. O(N)
C     Every directed edge u->v is part of two "angles", corresponding to the neighbours to v that aren't u,
C     corresponding to both a CW and a CCW traversal starting in the edge. (Likewise, every edge is part of four)
C     The angles are each counted exactly once if we trace the outline of each face in e.g. CCW order.
      do i=1,12
C     iterate over angles u--v--w
c         write (*,*) "Pentagon number",i,"has corners:"
         do j=1,5
            u = pentagons(j,i)
            v = pentagons(MOD(j,5)+1,i)
            w = pentagons(MOD(j+1,5)+1,i)
C     Do what needs to be done to u--v--w here. Each of these are part of a pentagon, obviously.

            a_p(1,5*(i-1)+j)=u+1
            a_p(2,5*(i-1)+j)=v+1
            a_p(3,5*(i-1)+j)=w+1

c            write (*,*) j,":",(/u,v,w/)
         end do
      end do

      do i=1,NH
c         write (*,*) "Hexagon number",i,"has corners:"
C     iterate over angles u--v--w
         do j=1,6
            u = hexagons(j,i)
            v = hexagons(MOD(j,6)+1,i)
            w = hexagons(MOD(j+1,6)+1,i)
C     Do what needs to be done to u--v--w here. Each of these are part of a hexagon, obviously.

            a_h(1,6*(i-1)+j)=u+1
            a_h(2,6*(i-1)+j)=v+1
            a_h(3,6*(i-1)+j)=w+1

c            write (*,*) j,":",(/u,v,w/)
         end do
      end do
      END SUBROUTINE


C     ------------------------------------------------------------
C                              DIHEDRALS
C     ------------------------------------------------------------
      SUBROUTINE get_dihedrals(graph,N,
     1 d_hhh,d_hhp,d_hpp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
      use iso_c_binding
      integer neighbours(3,N), face(6), lA,lB,lC, u,s,r,t
      type(c_ptr) :: graph
c     arrays for dihedrals. one per atom, starting in the middle
      integer d_hhh(4,n),d_hhp(4,n),d_hpp(4,n),d_ppp(4,n)
c     counter for dihedrals with 0, 1, 2, 3 pentagons neighbours
      integer nd_hhh,nd_hhp,nd_hpp,nd_ppp
      nd_hhh=0
      nd_hhp=0
      nd_hpp=0
      nd_ppp=0

      do j=1,4
      do i=1,n
        d_hhh(j,i)=0
        d_hhp(j,i)=0
        d_hpp(j,i)=0
        d_ppp(j,i)=0
      enddo
      enddo

      call adjacency_list(graph,3,neighbours)

      do u=1,N
C      s   B   t      
C        \   /
C       A  u   C
C          |
C          r
         r = neighbours(1,u)
         s = neighbours(2,u)
         t = neighbours(3,u)

c         write (*,*) "Dihedral ",u-1,r-1,s-1,t-1
         call get_face(graph,s,u,r,6,face,lA)
         call get_face(graph,s,u,t,6,face,lB)
         call get_face(graph,r,u,t,6,face,lC)

         select case ( lA+lB+lC )
         case ( 15 )            ! (5,5,5) - all pentagons
c            write (*,*) "555"
C     Do stuff here

          nd_ppp=nd_ppp+1
          d_ppp(1,nd_ppp)=u
          d_ppp(2,nd_ppp)=r
          d_ppp(3,nd_ppp)=s
          d_ppp(4,nd_ppp)=t

         case ( 16 )            ! Two pentagons, one hexagon
C     Do stuff common to all three (2,1)-cases here
            
C     Do case specific stuff here
            select case ( lA*100+lB*10+lC )
            case ( 655 )  ! BC are pentagons, u--t common edge
c               write (*,*) "655"

          nd_hpp=nd_hpp+1
          d_hpp(1,nd_hpp)=u
          d_hpp(2,nd_hpp)=r
          d_hpp(3,nd_hpp)=s
          d_hpp(4,nd_hpp)=t

            case ( 565 )  ! AC are pentagons, u--r common edge
c               write (*,*) "565"
            case ( 556 )  ! AB are pentagons, u--s common edge
c               write (*,*) "556"
            end select

         case ( 17 )            ! One pentagon, two hexagons
C     Do stuff common to all three (1,2)-cases here
            
C     Do case specific stuff here
            select case ( lA*100+lB*10+lC )
            case ( 566 )  ! BC are hexagons, u--t common edge
c               write (*,*) "566"

          nd_hhp=nd_hhp+1
          d_hhp(1,nd_hhp)=u
          d_hhp(2,nd_hhp)=r
          d_hhp(3,nd_hhp)=s
          d_hhp(4,nd_hhp)=t

            case ( 656 )  ! AC are hexagons, u--r common edge
c               write (*,*) "656"
            case ( 665 )  ! AB are hexagons, u--s common edge
c               write (*,*) "665"
            end select

         case ( 18 )            ! (6,6,6) - all hexagons
C     Do stuff here
c            write (*,*) "666"

          nd_hhh=nd_hhh+1
          d_hhh(1,nd_hhh)=u
          d_hhh(2,nd_hhh)=r
          d_hhh(3,nd_hhh)=s
          d_hhh(4,nd_hhh)=t

         case DEFAULT
            write (*,*) "INVALID: ",(/lA,lB,lC/)
         end select

      end do

      END SUBROUTINE

      
      SUBROUTINE get_hessian(coord, force, iopt, hessian,
     1  e_hh,e_hp,e_pp,ne_hh,ne_hp,ne_pp,
     1  a_h,a_p,
     1  d_hhh,d_hhp,d_hpp,d_ppp,nd_hhh,nd_hhp,nd_hpp,nd_ppp)
c      use iso_c_binding
      use config
c      type(c_ptr) :: graph
      implicit real*8 (a-h,o-z)
      integer iopt, i, j, m
      integer e_hh(2,3*number_vertices/2), e_hp(2,3*number_vertices/2),
     1 e_pp(2,3*number_vertices/2)
      integer ne_hh, ne_hp, ne_pp
      integer a_h(3,3*number_vertices-60), a_p(3,60)
      integer d_hhh(4,number_vertices), d_hhp(4,number_vertices),
     1 d_hpp(4,number_vertices), d_ppp(4,number_vertices)
      integer nd_hhh, nd_hhp, nd_hpp, nd_ppp
      integer a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12
      real(8) coord(number_vertices*3), force(ffmaxdim),
     1 hessian(3*number_vertices,3*number_vertices)
      real(8) k

c initialize variables to *something*
      ah=0.0
      ap=0.0
      dhhh=0.0
      dhhp=0.0
      dhpp=0.0
      dppp=0.0
      fah=0.0
      fap=0.0
      fco=0.0
      fdhhh=0.0
      fdhhp=0.0
      fdhpp=0.0
      fdppp=0.0
      frh=0.0
      frhh=0.0
      frhp=0.0
      frp=0.0
      frpp=0.0
      rh=0.0
      rhh=0.0
      rhp=0.0
      rp=0.0
      rpp=0.0

c init
      do i=1,3*number_vertices
        do j=1,3*number_vertices
          hessian(i,j)=0.0
        enddo
      enddo

c get force constants
      select case(iopt)
        case(1, 2)
          rp=force(1)
          rh=force(2)
          ap=force(3)
          ah=force(4)
          frp=force(5)
          frh=force(6)
          fap=force(7)
          fah=force(8)
          fco=force(9)
        case(3, 4)
          rpp=force(1)
          rhp=force(2)
          rhh=force(3)
          ap=force(4)
          ah=force(5)
          dppp=force(6)
          dhpp=force(7)
          dhhp=force(8)
          dhhh=force(9)
          frpp=force(10)
          frhp=force(11)
          frhh=force(12)
          fap=force(13)
          fah=force(14)
          fdppp=force(15)
          fdhpp=force(16)
          fdhhp=force(17)
          fdhhh=force(18)
          fco=force(19)
        case default
          write(*,*)'Something went horribly wrong: illegal iopt'
      end select

c edges
      edge_types: do i=1,3
        select case(10*iopt + i)
          case(11,21)
            k=frh
            r_naught=rh
            m=ne_hh
          case(12,22)
            k=frp
            r_naught=rp
            m=ne_hp
          case(13,23)
            k=frp
            r_naught=rp
            m=ne_pp
          case(31,41)
            k=frhh
            r_naught=rhh
            m=ne_hh
          case(32,42)
            k=frhp
            r_naught=rhp
            m=ne_hp
          case(33,43)
            k=frpp
            r_naught=rpp
            m=ne_pp
          case default
            write(*,*)'Something went horribly wrong: illegal iopt',
     1 ' or edge type'
            exit
        end select
        if(m.gt.0) then
          edges: do j=1,m
            select case(i)
              case(1)
                a1=3*e_hh(1,j)-2
                a2=3*e_hh(1,j)-1
                a3=3*e_hh(1,j)
                a4=3*e_hh(2,j)-2
                a5=3*e_hh(2,j)-1
                a6=3*e_hh(2,j)
              case(2)
                a1=3*e_hp(1,j)-2
                a2=3*e_hp(1,j)-1
                a3=3*e_hp(1,j)
                a4=3*e_hp(2,j)-2
                a5=3*e_hp(2,j)-1
                a6=3*e_hp(2,j)
              case(3)
                a1=3*e_pp(1,j)-2
                a2=3*e_pp(1,j)-1
                a3=3*e_pp(1,j)
                a4=3*e_pp(2,j)-2
                a5=3*e_pp(2,j)-1
                a6=3*e_pp(2,j)
              case default
                write(*,*)'Something went horribly wrong'
                exit
            end select
            ax=coord(a1)
            ay=coord(a2)
            az=coord(a3)
            bx=coord(a4)
            by=coord(a5)
            bz=coord(a6)
            call dddist(ax, ay, az, bx, by, bz,
     2       dax, day, daz, dbx, dby, dbz,
     3       daxax, daxay, daxaz, daxbx, daxby, daxbz, dayay, dayaz,
     1       daybx, dayby, daybz, dazaz, dazbx, dazby, dazbz, dbxbx,
     1       dbxby, dbxbz, dbyby, dbybz, dbzbz, dist)
c           (partial^2 E/partial x_i partial x_j)
c              = (partial^2 E/partial x_i partial r)(partial r/partial x_j) + (partial^2 r/partial x_i partial x_j)(partial E/partial r)
c              = (partial (k(r - r_0))/partial x_i)(partial r/partial x_j) + (partial^2 r/partial x_i partial x_j)(k(r - r_0))
c              = k * ((partial r/partial x_i)(partial r/partial x_j) + (partial^2 r/partial x_i partial x_j)(r - r_0))
            diff=dist - r_naught
            hessian(a1,a1)=hessian(a1,a1) + k * (dax*dax + daxax*diff)
            hessian(a1,a2)=hessian(a1,a2) + k * (dax*day + daxay*diff)
            hessian(a1,a3)=hessian(a1,a3) + k * (dax*daz + daxaz*diff)
            hessian(a1,a4)=hessian(a1,a4) + k * (dax*dbx + daxbx*diff)
            hessian(a1,a5)=hessian(a1,a5) + k * (dax*dby + daxby*diff)
            hessian(a1,a6)=hessian(a1,a6) + k * (dax*dbz + daxbz*diff)
            hessian(a2,a2)=hessian(a2,a2) + k * (day*day + dayay*diff)
            hessian(a2,a3)=hessian(a2,a3) + k * (day*daz + dayaz*diff)
            hessian(a2,a4)=hessian(a2,a4) + k * (day*dbx + daybx*diff)
            hessian(a2,a5)=hessian(a2,a5) + k * (day*dby + dayby*diff)
            hessian(a2,a6)=hessian(a2,a6) + k * (day*dbz + daybz*diff)
            hessian(a3,a3)=hessian(a3,a3) + k * (daz*daz + dazaz*diff)
            hessian(a3,a4)=hessian(a3,a4) + k * (daz*dbx + dazbx*diff)
            hessian(a3,a5)=hessian(a3,a5) + k * (daz*dby + dazby*diff)
            hessian(a3,a6)=hessian(a3,a6) + k * (daz*dbz + dazbz*diff)
            hessian(a4,a4)=hessian(a4,a4) + k * (dbx*dbx + dbxbx*diff)
            hessian(a4,a5)=hessian(a4,a5) + k * (dbx*dby + dbxby*diff)
            hessian(a4,a6)=hessian(a4,a6) + k * (dbx*dbz + dbxbz*diff)
            hessian(a5,a5)=hessian(a5,a5) + k * (dby*dby + dbyby*diff)
            hessian(a5,a6)=hessian(a5,a6) + k * (dby*dbz + dbybz*diff)
            hessian(a6,a6)=hessian(a6,a6) + k * (dbz*dbz + dbzbz*diff)
          end do edges
        endif
      end do edge_types
      
c angles
      angle_types: do i=1,2
c       iopt doesn't matter in this case
        select case(i)
          case(1)
            k=fah
            a_naught=ah
            m=3*number_vertices-60
          case(2)
            k=fap
            a_naught=ap
            m=60
          case default
            write(*,*)'Something went horribly wrong'
            exit
        end select
        if(m.gt.0)then
          angles: do j=1,m
            select case(i)
              case(1)
                a1=3*a_h(1,j)-2
                a2=3*a_h(1,j)-1
                a3=3*a_h(1,j)
                a4=3*a_h(2,j)-2
                a5=3*a_h(2,j)-1
                a6=3*a_h(2,j)
                a7=3*a_h(3,j)-2
                a8=3*a_h(3,j)-1
                a9=3*a_h(3,j)
              case(2)
                a1=3*a_p(1,j)-2
                a2=3*a_p(1,j)-1
                a3=3*a_p(1,j)
                a4=3*a_p(2,j)-2
                a5=3*a_p(2,j)-1
                a6=3*a_p(2,j)
                a7=3*a_p(3,j)-2
                a8=3*a_p(3,j)-1
                a9=3*a_p(3,j)
              case default
                write(*,*)'Something went horribly wrong'
                exit
            end select
            ax=coord(a1)
            ay=coord(a2)
            az=coord(a3)
            bx=coord(a4)
            by=coord(a5)
            bz=coord(a6)
            cx=coord(a7)
            cy=coord(a8)
            cz=coord(a9)
            call ddangle(ax, ay, az, bx, by, bz, cx, cy, cz,
     1       dax, day, daz, dbx, dby, dbz, dcx, dcy, dcz,
     1       daxax, daxay, daxaz, daxbx, daxby, daxbz, daxcx, daxcy,
     1       daxcz, dayay, dayaz, daybx, dayby, daybz, daycx, daycy,
     1       daycz, dazaz, dazbx, dazby, dazbz, dazcx, dazcy, dazcz,
     1       dbxbx, dbxby, dbxbz, dbxcx, dbxcy, dbxcz, dbyby, dbybz,
     1       dbycx, dbycy, dbycz, dbzbz, dbzcx, dbzcy, dbzcz, dcxcx,
     1       dcxcy, dcxcz, dcycy, dcycz, dczcz,
     1       angle_abc)
            diff=angle_abc - a_naught
            hessian(a1,a1)=hessian(a1,a1) + k * (dax*dax + daxax*diff)
            hessian(a1,a2)=hessian(a1,a2) + k * (dax*day + daxay*diff)
            hessian(a1,a3)=hessian(a1,a3) + k * (dax*daz + daxaz*diff)
            hessian(a1,a4)=hessian(a1,a4) + k * (dax*dbx + daxbx*diff)
            hessian(a1,a5)=hessian(a1,a5) + k * (dax*dby + daxby*diff)
            hessian(a1,a6)=hessian(a1,a6) + k * (dax*dbz + daxbz*diff)
            hessian(a1,a7)=hessian(a1,a7) + k * (dax*dcx + daxcx*diff)
            hessian(a1,a8)=hessian(a1,a8) + k * (dax*dcy + daxcy*diff)
            hessian(a1,a9)=hessian(a1,a9) + k * (dax*dcz + daxcz*diff)
            hessian(a2,a2)=hessian(a2,a2) + k * (day*day + dayay*diff)
            hessian(a2,a3)=hessian(a2,a3) + k * (day*daz + dayaz*diff)
            hessian(a2,a4)=hessian(a2,a4) + k * (day*dbx + daybx*diff)
            hessian(a2,a5)=hessian(a2,a5) + k * (day*dby + dayby*diff)
            hessian(a2,a6)=hessian(a2,a6) + k * (day*dbz + daybz*diff)
            hessian(a2,a7)=hessian(a2,a7) + k * (day*dcx + daycx*diff)
            hessian(a2,a8)=hessian(a2,a8) + k * (day*dcy + daycy*diff)
            hessian(a2,a9)=hessian(a2,a9) + k * (day*dcz + daycz*diff)
            hessian(a3,a3)=hessian(a3,a3) + k * (daz*daz + dazaz*diff)
            hessian(a3,a4)=hessian(a3,a4) + k * (daz*dbx + dazbx*diff)
            hessian(a3,a5)=hessian(a3,a5) + k * (daz*dby + dazby*diff)
            hessian(a3,a6)=hessian(a3,a6) + k * (daz*dbz + dazbz*diff)
            hessian(a3,a7)=hessian(a3,a7) + k * (daz*dcx + dazcx*diff)
            hessian(a3,a8)=hessian(a3,a8) + k * (daz*dcy + dazcy*diff)
            hessian(a3,a9)=hessian(a3,a9) + k * (daz*dcz + dazcz*diff)
            hessian(a4,a4)=hessian(a4,a4) + k * (dbx*dbx + dbxbx*diff)
            hessian(a4,a5)=hessian(a4,a5) + k * (dbx*dby + dbxby*diff)
            hessian(a4,a6)=hessian(a4,a6) + k * (dbx*dbz + dbxbz*diff)
            hessian(a4,a7)=hessian(a4,a7) + k * (dbx*dcx + dbxcx*diff)
            hessian(a4,a8)=hessian(a4,a8) + k * (dbx*dcy + dbxcy*diff)
            hessian(a4,a9)=hessian(a4,a9) + k * (dbx*dcz + dbxcz*diff)
            hessian(a5,a5)=hessian(a5,a5) + k * (dby*dby + dbyby*diff)
            hessian(a5,a6)=hessian(a5,a6) + k * (dby*dbz + dbybz*diff)
            hessian(a5,a7)=hessian(a5,a7) + k * (dby*dcx + dbycx*diff)
            hessian(a5,a8)=hessian(a5,a8) + k * (dby*dcy + dbycy*diff)
            hessian(a5,a9)=hessian(a5,a9) + k * (dby*dcz + dbycz*diff)
            hessian(a6,a6)=hessian(a6,a6) + k * (dbz*dbz + dbzbz*diff)
            hessian(a6,a7)=hessian(a6,a7) + k * (dbz*dcx + dbzcx*diff)
            hessian(a6,a8)=hessian(a6,a8) + k * (dbz*dcy + dbzcy*diff)
            hessian(a6,a9)=hessian(a6,a9) + k * (dbz*dcz + dbzcz*diff)
            hessian(a7,a7)=hessian(a7,a7) + k * (dcx*dcx + dcxcx*diff)
            hessian(a7,a8)=hessian(a7,a8) + k * (dcx*dcy + dcxcy*diff)
            hessian(a7,a9)=hessian(a7,a9) + k * (dcx*dcz + dcxcz*diff)
            hessian(a8,a8)=hessian(a8,a8) + k * (dcy*dcy + dcycy*diff)
            hessian(a8,a9)=hessian(a8,a9) + k * (dcy*dcz + dcycz*diff)
            hessian(a9,a9)=hessian(a9,a9) + k * (dcz*dcz + dczcz*diff)
          end do angles
        endif
      end do angle_types

c dihedrals
      dihedral_types: do i=1,4
        select case(iopt)
          case(1,2)
c           no dihedrals in case of iopt=1,2
            exit dihedral_types
          case(3,4)
        end select
        select case(i)
          case(1)
            k=fdhhh
            d_naught=dhhh
            m=nd_hhh
          case(2)
            k=fdhhp
            d_naught=dhhp
            m=nd_hhp
          case(3)
            k=fdhpp
            d_naught=dhpp
            m=nd_hpp
          case(4)
            k=fdppp
            d_naught=dppp
            m=nd_ppp
          case default
            write(*,*)'Something went horribly wrong'
            exit
        end select
        if(m.gt.0)then
          dihedrals: do j=1,m
            select case(i)
              case(1)
                a1=3*d_hhh(1,j)-2
                a2=3*d_hhh(1,j)-1
                a3=3*d_hhh(1,j)
                a4=3*d_hhh(2,j)-2
                a5=3*d_hhh(2,j)-1
                a6=3*d_hhh(2,j)
                a7=3*d_hhh(3,j)-2
                a8=3*d_hhh(3,j)-1
                a9=3*d_hhh(3,j)
                a10=3*d_hhh(4,j)-2
                a11=3*d_hhh(4,j)-1
                a12=3*d_hhh(4,j)
              case(2)
                a1=3*d_hhp(1,j)-2
                a2=3*d_hhp(1,j)-1
                a3=3*d_hhp(1,j)
                a4=3*d_hhp(2,j)-2
                a5=3*d_hhp(2,j)-1
                a6=3*d_hhp(2,j)
                a7=3*d_hhp(3,j)-2
                a8=3*d_hhp(3,j)-1
                a9=3*d_hhp(3,j)
                a10=3*d_hhp(4,j)-2
                a11=3*d_hhp(4,j)-1
                a12=3*d_hhp(4,j)
              case(3)
                a1=3*d_hpp(1,j)-2
                a2=3*d_hpp(1,j)-1
                a3=3*d_hpp(1,j)
                a4=3*d_hpp(2,j)-2
                a5=3*d_hpp(2,j)-1
                a6=3*d_hpp(2,j)
                a7=3*d_hpp(3,j)-2
                a8=3*d_hpp(3,j)-1
                a9=3*d_hpp(3,j)
                a10=3*d_hpp(4,j)-2
                a11=3*d_hpp(4,j)-1
                a12=3*d_hpp(4,j)
              case(4)
                a1=3*d_ppp(1,j)-2
                a2=3*d_ppp(1,j)-1
                a3=3*d_ppp(1,j)
                a4=3*d_ppp(2,j)-2
                a5=3*d_ppp(2,j)-1
                a6=3*d_ppp(2,j)
                a7=3*d_ppp(3,j)-2
                a8=3*d_ppp(3,j)-1
                a9=3*d_ppp(3,j)
                a10=3*d_ppp(4,j)-2
                a11=3*d_ppp(4,j)-1
                a12=3*d_ppp(4,j)
              case default
                write(*,*)'Something went horribly wrong'
                exit
            end select
            ax=coord(a1)
            ay=coord(a2)
            az=coord(a3)
            bx=coord(a4)
            by=coord(a5)
            bz=coord(a6)
            cx=coord(a7)
            cy=coord(a8)
            cz=coord(a9)
            dx=coord(a10)
            dy=coord(a11)
            dz=coord(a12)
            call dddihedral(
     1       ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz,
     1       dax, day, daz, dbx, dby, dbz, dcx, dcy, dcz, ddx, ddy, ddz,
     1       daxax, daxay, daxaz, daxbx, daxby, daxbz, daxcx, daxcy,
     1       daxcz, daxdx, daxdy, daxdz, dayay, dayaz, daybx, dayby,
     1       daybz, daycx, daycy, daycz, daydx, daydy, daydz,
     1       dazaz, dazbx, dazby, dazbz, dazcx, dazcy, dazcz, dazdx,
     1       dazdy, dazdz, dbxbx, dbxby, dbxbz, dbxcx,
     1       dbxcy, dbxcz, dbxdx, dbxdy, dbxdz,
     1       dbyby, dbybz, dbycx, dbycy, dbycz, dbydx, dbydy, dbydz,
     1       dbzbz, dbzcx, dbzcy, dbzcz, dbzdx, dbzdy, dbzdz,
     1       dcxcx, dcxcy, dcxcz, dcxdx, dcxdy, dcxdz,
     1       dcycy, dcycz, dcydx, dcydy, dcydz,
     1       dczcz, dczdx, dczdy, dczdz, ddxdx, ddxdy, ddxdz,
     1       ddydy, ddydz, ddzdz,
     1       dihedral_abcd)
            diff=dihedral_abcd - d_naught
            hessian(a1,a1) =hessian(a1,a1)   + k *(dax*dax + daxax*diff)
            hessian(a1,a2) =hessian(a1,a2)   + k *(dax*day + daxay*diff)
            hessian(a1,a3) =hessian(a1,a3)   + k *(dax*daz + daxaz*diff)
            hessian(a1,a4) =hessian(a1,a4)   + k *(dax*dbx + daxbx*diff)
            hessian(a1,a5) =hessian(a1,a5)   + k *(dax*dby + daxby*diff)
            hessian(a1,a6) =hessian(a1,a6)   + k *(dax*dbz + daxbz*diff)
            hessian(a1,a7) =hessian(a1,a7)   + k *(dax*dcx + daxcx*diff)
            hessian(a1,a8) =hessian(a1,a8)   + k *(dax*dcy + daxcy*diff)
            hessian(a1,a9) =hessian(a1,a9)   + k *(dax*dcz + daxcz*diff)
            hessian(a1,a10)=hessian(a1,a10)  + k *(dax*ddx + daxdx*diff)
            hessian(a1,a11)=hessian(a1,a11)  + k *(dax*ddy + daxdy*diff)
            hessian(a1,a12)=hessian(a1,a12)  + k *(dax*ddz + daxdz*diff)
            hessian(a2,a2) =hessian(a2,a2)   + k *(day*day + dayay*diff)
            hessian(a2,a3) =hessian(a2,a3)   + k *(day*daz + dayaz*diff)
            hessian(a2,a4) =hessian(a2,a4)   + k *(day*dbx + daybx*diff)
            hessian(a2,a5) =hessian(a2,a5)   + k *(day*dby + dayby*diff)
            hessian(a2,a6) =hessian(a2,a6)   + k *(day*dbz + daybz*diff)
            hessian(a2,a7) =hessian(a2,a7)   + k *(day*dcx + daycx*diff)
            hessian(a2,a8) =hessian(a2,a8)   + k *(day*dcy + daycy*diff)
            hessian(a2,a9) =hessian(a2,a9)   + k *(day*dcz + daycz*diff)
            hessian(a2,a10)=hessian(a2,a10)  + k *(day*ddx + daydx*diff)
            hessian(a2,a11)=hessian(a2,a11)  + k *(day*ddy + daydy*diff)
            hessian(a2,a12)=hessian(a2,a12)  + k *(day*ddz + daydz*diff)
            hessian(a3,a3) =hessian(a3,a3)   + k *(daz*daz + dazaz*diff)
            hessian(a3,a4) =hessian(a3,a4)   + k *(daz*dbx + dazbx*diff)
            hessian(a3,a5) =hessian(a3,a5)   + k *(daz*dby + dazby*diff)
            hessian(a3,a6) =hessian(a3,a6)   + k *(daz*dbz + dazbz*diff)
            hessian(a3,a7) =hessian(a3,a7)   + k *(daz*dcx + dazcx*diff)
            hessian(a3,a8) =hessian(a3,a8)   + k *(daz*dcy + dazcy*diff)
            hessian(a3,a9) =hessian(a3,a9)   + k *(daz*dcz + dazcz*diff)
            hessian(a3,a10)=hessian(a3,a10)  + k *(daz*ddx + dazdx*diff)
            hessian(a3,a11)=hessian(a3,a11)  + k *(daz*ddy + dazdy*diff)
            hessian(a3,a12)=hessian(a3,a12)  + k *(daz*ddz + dazdz*diff)
            hessian(a4,a4) =hessian(a4,a4)   + k *(dbx*dbx + dbxbx*diff)
            hessian(a4,a5) =hessian(a4,a5)   + k *(dbx*dby + dbxby*diff)
            hessian(a4,a6) =hessian(a4,a6)   + k *(dbx*dbz + dbxbz*diff)
            hessian(a4,a7) =hessian(a4,a7)   + k *(dbx*dcx + dbxcx*diff)
            hessian(a4,a8) =hessian(a4,a8)   + k *(dbx*dcy + dbxcy*diff)
            hessian(a4,a9) =hessian(a4,a9)   + k *(dbx*dcz + dbxcz*diff)
            hessian(a4,a10)=hessian(a4,a10)  + k *(dbx*ddx + dbxdx*diff)
            hessian(a4,a11)=hessian(a4,a11)  + k *(dbx*ddy + dbxdy*diff)
            hessian(a4,a12)=hessian(a4,a12)  + k *(dbx*ddz + dbxdz*diff)
            hessian(a5,a5) =hessian(a5,a5)   + k *(dby*dby + dbyby*diff)
            hessian(a5,a6) =hessian(a5,a6)   + k *(dby*dbz + dbybz*diff)
            hessian(a5,a7) =hessian(a5,a7)   + k *(dby*dcx + dbycx*diff)
            hessian(a5,a8) =hessian(a5,a8)   + k *(dby*dcy + dbycy*diff)
            hessian(a5,a9) =hessian(a5,a9)   + k *(dby*dcz + dbycz*diff)
            hessian(a5,a10)=hessian(a5,a10)  + k *(dby*ddx + dbydx*diff)
            hessian(a5,a11)=hessian(a5,a11)  + k *(dby*ddy + dbydy*diff)
            hessian(a5,a12)=hessian(a5,a12)  + k *(dby*ddz + dbydz*diff)
            hessian(a6,a6) =hessian(a6,a6)   + k *(dbz*dbz + dbzbz*diff)
            hessian(a6,a7) =hessian(a6,a7)   + k *(dbz*dcx + dbzcx*diff)
            hessian(a6,a8) =hessian(a6,a8)   + k *(dbz*dcy + dbzcy*diff)
            hessian(a6,a9) =hessian(a6,a9)   + k *(dbz*dcz + dbzcz*diff)
            hessian(a6,a10)=hessian(a6,a10)  + k *(dbz*ddx + dbzdx*diff)
            hessian(a6,a11)=hessian(a6,a11)  + k *(dbz*ddy + dbzdy*diff)
            hessian(a6,a12)=hessian(a6,a12)  + k *(dbz*ddz + dbzdz*diff)
            hessian(a7,a7) =hessian(a7,a7)   + k *(dcx*dcx + dcxcx*diff)
            hessian(a7,a8) =hessian(a7,a8)   + k *(dcx*dcy + dcxcy*diff)
            hessian(a7,a9) =hessian(a7,a9)   + k *(dcx*dcz + dcxcz*diff)
            hessian(a7,a10)=hessian(a7,a10)  + k *(dcx*ddx + dcxdx*diff)
            hessian(a7,a11)=hessian(a7,a11)  + k *(dcx*ddy + dcxdy*diff)
            hessian(a7,a12)=hessian(a7,a12)  + k *(dcx*ddz + dcxdz*diff)
            hessian(a8,a8) =hessian(a8,a8)   + k *(dcy*dcy + dcycy*diff)
            hessian(a8,a9) =hessian(a8,a9)   + k *(dcy*dcz + dcycz*diff)
            hessian(a8,a10)=hessian(a8,a10)  + k *(dcy*ddx + dcydx*diff)
            hessian(a8,a11)=hessian(a8,a11)  + k *(dcy*ddy + dcydy*diff)
            hessian(a8,a12)=hessian(a8,a12)  + k *(dcy*ddz + dcydz*diff)
            hessian(a9,a9) =hessian(a9,a9)   + k *(dcz*dcz + dczcz*diff)
            hessian(a9,a10)=hessian(a9,a10)  + k *(dcz*ddx + dczdx*diff)
            hessian(a9,a11)=hessian(a9,a11)  + k *(dcz*ddy + dczdy*diff)
            hessian(a9,a12)=hessian(a9,a12)  + k *(dcz*ddz + dczdz*diff)
            hessian(a10,a10)=hessian(a10,a10)+ k *(ddx*ddx + ddxdx*diff)
            hessian(a10,a11)=hessian(a10,a11)+ k *(ddx*ddy + ddxdy*diff)
            hessian(a10,a12)=hessian(a10,a12)+ k *(ddx*ddz + ddxdz*diff)
            hessian(a11,a11)=hessian(a11,a11)+ k *(ddy*ddy + ddydy*diff)
            hessian(a11,a12)=hessian(a11,a12)+ k *(ddy*ddz + ddydz*diff)
            hessian(a12,a12)=hessian(a12,a12)+ k *(ddz*ddz + ddzdz*diff)
          end do dihedrals
        endif
      end do dihedral_types

c coulomb
      if(iopt.eq.2 .or. iopt.eq.4) then
        atoms: do j=1,number_vertices
          k=fco
          a1=3*number_vertices-2
          a2=3*number_vertices-1
          a3=3*number_vertices
          ax=coord(a1)
          ay=coord(a2)
          az=coord(a3)
          call ddcoulomb(ax, ay, az, dax, day, daz, 
     1      daxax, daxay, daxaz, dayay, dayaz, dazaz, c)
          hessian(a1,a1)=hessian(a1,a1) + k * (dax*dax + daxax*c)
          hessian(a1,a2)=hessian(a1,a2) + k * (dax*day + daxay*c)
          hessian(a1,a3)=hessian(a1,a3) + k * (dax*daz + daxaz*c)
          hessian(a2,a2)=hessian(a2,a2) + k * (day*day + dayay*c)
          hessian(a2,a3)=hessian(a2,a3) + k * (day*daz + dayaz*c)
          hessian(a3,a3)=hessian(a3,a3) + k * (daz*daz + dazaz*c)
        end do atoms
      endif

c copy hessian to the other half
      do i=1,3*number_vertices
        do j=i+1,3*number_vertices
          hessian(i,j)=hessian(j,i)+hessian(i,j)
          hessian(j,i)=hessian(i,j)
        enddo
      enddo      

      return
      END SUBROUTINE

